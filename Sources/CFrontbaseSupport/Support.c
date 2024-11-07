#include "Support.h"
#include <string.h>
#include <sys/stat.h>
#include <stdlib.h> // for malloc()

// Internal
static char *_fbcCopyAllMessages(FBCMetaData*);
static char *_fbcCopyError(const char *);

const char* digestPassword (const char* username, const char* password, char* digest) {
	if (password == NULL) {
		return NULL;
	} else {
		return fbcDigestPassword (username, password, digest);
	}
}

/// Return a copy of all error messages associated with `md`, or `NULL` if there are none.
/// The caller must free the returned string.
/// The rationale for this function is this note from the meastro:
///   "You should always use fbcemdReleaseMessage on the result from fbcemdAllErrorMessages"
static char *_fbcCopyAllMessages(FBCMetaData *md) {
	if (!fbcmdErrorsFound(md)) return NULL;

	FBCErrorMetaData *emd = fbcmdErrorMetaData(md);
	char *allMessages = NULL;
	char *copy = NULL;

	if ((allMessages = fbcemdAllErrorMessages(emd)) != NULL) {
        copy = _fbcCopyError(allMessages);
		fbcemdReleaseMessage(allMessages);
	}

	fbcemdRelease(emd);

	return copy;
}

/// Return a copy of the NULL terminated string `msg`.
/// The caller is responsible for freeing the copy.
static char *_fbcCopyError(const char *msg) {
	unsigned long len = strlen(msg);
	char *copy = (char *)malloc(len + 1);
	memcpy(copy, msg, len);
	copy[len] = 0;
	return copy;
}

/// Open a connection through FBExec on a host, and create a session.
/// Any returned FBSConnection MUST be deallocated using fbsClose().
/// If NULL is returned, *errorMessage will contain a message.
FBSConnection fbsConnectDatabaseOnHost (const char* databaseName,
										const char* hostName,
										const char* databasePassword,
										const char* username,
										const char* password,
                                        const char* defaultSessionName,
                                        const char* operatingSystemUser,
										const char** errorMessage) {
	const char* localError = NULL;
	char digest[1000];
	FBCDatabaseConnection* connection = fbcdcConnectToDatabaseRM (databaseName, hostName, digestPassword ("_SYSTEM", databasePassword, digest), &localError);
	FBCMetaData* session;
	FBCErrorMetaData* errorMetaData;

	if (connection == NULL) {
		if (errorMessage != NULL) {
			*errorMessage = localError;
		}
		return NULL;
	}

	session = fbcdcCreateSession (connection, defaultSessionName, username, digestPassword (username, password, digest), operatingSystemUser);

	if (session == NULL) {
		fbcdcClose (connection);
		fbcdcRelease (connection);

		return NULL;
	} else if (fbcmdErrorsFound (session)) {
		if (errorMessage != NULL) {
			errorMetaData = fbcmdErrorMetaData (session);
			*errorMessage = fbcemdAllErrorMessages (errorMetaData);
			fbcemdRelease (errorMetaData);
		}

		fbcmdRelease (session);
		fbcdcClose (connection);
		fbcdcRelease (connection);

		return NULL;
	} else {
        fbcdcSetFormatResult (connection, 0);

        const char* timeZoneMessage = NULL;

        FBSResult result = fbsExecuteSQL (connection, "SET TIME ZONE 'UTC';", 1, &timeZoneMessage);

        if (result == NULL) {
            if (errorMessage != NULL) {
                *errorMessage = timeZoneMessage;
            }

            fbcmdRelease (session);
            fbcdcClose (connection);
            fbcdcRelease (connection);

            return NULL;
        }

		return fbcdcRetain (connection);
	}
}

/// Open a connection at a port on a host, and create a session.
/// Any returned FBSConnection MUST be deallocated using fbsClose().
/// If NULL is returned, *errorMessage will contain a message.
FBSConnection fbsConnectDatabaseOnPort (const char* hostName,
                                        unsigned port,
                                        const char* databasePassword,
										const char* username,
										const char* password,
                                        const char* defaultSessionName,
                                        const char* operatingSystemUser,
										const char** errorMessage) {
	const char* localError = NULL;
	char digest[1000];
	FBCDatabaseConnection* connection = fbcdcConnectToDatabaseUsingPortRM (hostName, port, digestPassword ("_SYSTEM", databasePassword, digest), &localError);
	FBCMetaData* session;
	FBCErrorMetaData* errorMetaData;

	if (connection == NULL) {
		if (errorMessage != NULL) {
			*errorMessage = localError;
		}
		return NULL;
	}

	session = fbcdcCreateSession (connection, defaultSessionName, username, digestPassword (username, password, digest), operatingSystemUser);

	if (session == NULL) {
		fbcdcClose (connection);
		fbcdcRelease (connection);

		return NULL;
	} else if (fbcmdErrorsFound (session)) {
		if (errorMessage != NULL) {
			errorMetaData = fbcmdErrorMetaData (session);
			*errorMessage = fbcemdAllErrorMessages (errorMetaData);
			fbcemdRelease (errorMetaData);
		}

		fbcmdRelease (session);
		fbcdcClose (connection);
		fbcdcRelease (connection);

		return NULL;
	} else {
        fbcdcSetFormatResult (connection, 0);

        const char* timeZoneMessage = NULL;

        FBSResult result = fbsExecuteSQL (connection, "SET TIME ZONE 'UTC';", 1, &timeZoneMessage);

        if (result == NULL) {
            if (errorMessage != NULL) {
                *errorMessage = timeZoneMessage;
            }

            fbcmdRelease (session);
            fbcdcClose (connection);
            fbcdcRelease (connection);

            return NULL;
        }

		return fbcdcRetain (connection);
	}
}

/// Open a connection to a local database file, and create a session.
/// Any returned FBSConnection MUST be deallocated using fbsClose().
/// If NULL is returned, *errorMessage will contain a message.
FBSConnection fbsConnectDatabaseAtPath (const char* databaseName,
										const char* filePath,
										const char* databasePassword,
										const char* username,
										const char* password,
                                        const char* defaultSessionName,
                                        const char* operatingSystemUser,
										const char** errorMessage) {
	const char* localError = NULL;
	char digest[1000];
	char url[1025];

	int n = snprintf(url, 1025, "file://%s", filePath);
	if (n >= 1025) {
		if (errorMessage != NULL) {
			*errorMessage = _fbcCopyError("path too long");
		}
		return NULL;
	}

	FBCMetaData *md = fbcdcConnectToURL(url, digestPassword ("_SYSTEM", databasePassword, digest), username, digestPassword (username, password, digest),defaultSessionName);

	if (fbcmdErrorsFound(md)) {
		if (errorMessage != NULL) {
			*errorMessage = _fbcCopyAllMessages(md);
		}

		fbcmdRelease(md);
		return NULL;
	}

	FBCDatabaseConnection *connection = fbcdcRetain(fbcmdDatabaseConnection(md));
	fbcmdRelease(md);
	md = NULL;

	fbcdcSetFormatResult (connection, 0);

	const char* timeZoneMessage = NULL;

	FBSResult result = fbsExecuteSQL (connection, "SET TIME ZONE 'UTC';", 1, &timeZoneMessage);

	if (result == NULL) {
		if (errorMessage != NULL) {
			*errorMessage = timeZoneMessage;
		}

		fbcdcClose (connection);
		fbcdcRelease (connection);

		return NULL;
	}

	return connection;
}

/// Close database connection, and deallocate data structures.
void fbsCloseConnection (FBSConnection connection) {
	FBCDatabaseConnection* databaseConnection = connection;

	if (databaseConnection != NULL) {
		fbcdcClose (databaseConnection);
		fbcdcRelease (databaseConnection);
	}
}
/// Create a database with the specified Frontbase URL
void fbsCreateDatabaseWithUrl (const char* url) {
	fbcdCreate (url, "");
}

/// Start database with the specified Frontbase URL
void fbsStartDatabaseWithUrl (const char* url) {
	fbcdStart (url, "");
}

/// Delete a database with the specified Frontbase URL
void fbsDeleteDatabaseWithUrl (const char* url) {
	fbcdStop (url);
	fbcdDelete (url);
}

/// Returns true if connection is non-null and has an active session,
/// otherwise false
bool fbsConnectionIsOpen (FBSConnection connection) {
	FBCDatabaseConnection* databaseConnection = connection;

	return (databaseConnection != NULL) && fbcdcConnected (databaseConnection);
}

/// Returns the latest error message for connection
const char* fbsErrorMessage (FBSConnection connection) {
	FBCDatabaseConnection* databaseConnection = connection;

	return fbcdcErrorMessage (databaseConnection);
}

/// Execute SQL
/// Any returned FBSResult MUST be deallocated using fbsCloseResult().
/// If NULL is returned, *errorMessage will contain a message.
FBSResult fbsExecuteSQL (FBSConnection connection,
                         const char* sql,
                         bool autoCommit,
                         const char** errorMessage) {
	FBCDatabaseConnection* databaseConnection = connection;
    FBCMetaData* metadata = fbcdcExecuteSQL (databaseConnection, (char*)sql, (unsigned int)strlen (sql), autoCommit ? FBCDCCommit : 0);

	if (fbcmdErrorsFound (metadata)) {
		if (errorMessage != NULL) {
			*errorMessage = _fbcCopyAllMessages(metadata);
		}

		fbcmdRelease (metadata);

		return NULL;
	} else {
		return metadata;
	}
}

/// Close result set, and deallocate data structures.
void fbsCloseResult (FBSResult result) {
	FBCMetaData* metadata = result;

	if (metadata != NULL) {
		fbcmdRelease (metadata);
	}
}

/// Fetch a row from a result set
/// Any returned FBSRow MUST be deallocated using fbsReleaseRow().
/// If NULL is returned, there are no more rows to fetch.
FBSRow fbsFetchRow (FBSResult result) {
	FBCMetaData* metadata = result;
	FBCRow* row = fbcmdFetchRow (metadata);

	if (row == NULL) {
		return NULL;
	} else {
		return row;
	}
}

/// Release result row, and deallocate data structures.
void fbsReleaseRow (FBSRow row) {
	if (row != NULL) {
		fbcrRelease (row);
	}
}

/// Get number of columns in result
unsigned fbsGetColumnCount (FBSResult result) {
	return fbcmdColumnCount (result);
}

FBSDatatype datatypeFromFBCDataTypeCode (FBCDatatypeCode code) {
	switch (code) {
		case FB_PrimaryKey:
			return FBS_PrimaryKey;

		case FB_Boolean:
			return FBS_Boolean;

		case FB_Integer:
			return FBS_Integer;

		case FB_SmallInteger:
			return FBS_SmallInteger;

		case FB_Float:
			return FBS_Float;

		case FB_Real:
			return FBS_Real;

		case FB_Double:
			return FBS_Double;

		case FB_Numeric:
			return FBS_Numeric;

		case FB_Decimal:
			return FBS_Decimal;

		case FB_Character:
			return FBS_Character;

		case FB_VCharacter:
			return FBS_VCharacter;

		case FB_Bit:
			return FBS_Bit;

		case FB_VBit:
			return FBS_VBit;

		case FB_Date:
			return FBS_Date;

		case FB_Time:
			return FBS_Time;

		case FB_TimeTZ:
			return FBS_TimeTZ;

		case FB_Timestamp:
			return FBS_Timestamp;

		case FB_TimestampTZ:
			return FBS_TimestampTZ;

		case FB_YearMonth:
			return FBS_YearMonth;

		case FB_DayTime:
			return FBS_DayTime;

		case FB_CLOB:
			return FBS_CLOB;

		case FB_BLOB:
			return FBS_BLOB;

		case FB_TinyInteger:
			return FBS_TinyInteger;

		case FB_LongInteger:
			return FBS_LongInteger;

		case FB_CircaDate:
			return FBS_CircaDate;

		case FB_AnyType:
			return FBS_AnyType;

		case FB_Undecided:
			return FBS_Undecided;
	}
}

FBSDatatype fbsDatatype (const FBCDatatypeMetaData* metadata) {
    return datatypeFromFBCDataTypeCode (fbcdmdDatatypeCode (metadata));
}

/// Get column information
const FBSColumnInfo fbsGetColumnInfoAtIndex (FBSResult result, unsigned column) {
	FBCMetaData* metadata = result;
	const FBCColumnMetaData* columnMetadata = fbcmdColumnMetaDataAtIndex (metadata, column);
	const FBCDatatypeMetaData* datatypeMetadata = fbcmdDatatypeMetaDataAtIndex (metadata, column);
	FBSColumnInfo info;

	info.tableName = fbccmdTableName (columnMetadata);
	info.labelName = fbccmdLabelName (columnMetadata);
	info.datatype = fbsDatatype (datatypeMetadata);
    info.isNullable = fbccmdIsNullable (columnMetadata);

	return info;
}
	
unsigned fbsGetColumnIndex (FBCMetaData* result, const char* columnName, FBDatatypeCode* datatypeCode) {
	for (unsigned column = 0; column < fbcmdColumnCount (result); column += 1) {
		const FBCColumnMetaData* columnMetadata = fbcmdColumnMetaDataAtIndex (result, column);
		const FBCDatatypeMetaData* datatypeMetadata = fbcmdDatatypeMetaDataAtIndex (result, column);

		if (strcasecmp (fbccmdLabelName (columnMetadata), columnName) == 0) {
			*datatypeCode = fbcdmdDatatypeCode (datatypeMetadata);

			return column;
		}
	}

	return -1;
}

/// Tests if a value from a result row is null
bool fbsIsNull (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column] == NULL;
}

/// Return a boolean value from a result row.
bool fbsGetBoolean (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->boolean != 0;
}

/// Return a tiny integer value from a result row.
long long fbsGetTinyInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->tinyInteger;
}

/// Return a short integer value from a result row.
long long fbsGetShortInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->shortInteger;
}

/// Return a integer value from a result row.
long long fbsGetInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->integer;
}

/// Return a long integer value from a result row.
long long fbsGetLongInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->longInteger;
}

/// Return a numeric value from a result row.
double fbsGetNumeric (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->numeric;
}

/// Return a real value from a result row.
double fbsGetReal (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->real;
}

/// Return a decimal value from a result row.
double fbsGetDecimal (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->decimal;
}

/// Return scale of value from a result row.
long fbsGetScale (FBSResult result, FBSRow row, unsigned column) {
    FBCRow* fbcRow = row;
    const FBCDatatypeMetaData* datatypeMetadata = fbcmdDatatypeMetaDataAtIndex (result, column);

    return fbcdmdScale (datatypeMetadata);
}

/// Return a character value from a result row.
const char* fbsGetCharacter (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->character;
}

/// Return a blob handle from a result row
const char* fbsGetBlobHandle (FBSRow row, unsigned column, unsigned* size) {
	FBCRow* fbcRow = row;

	*size = fbcrLOBSize (&fbcRow[column]->blob);
	return fbcRow[column]->blob.handleAsString;
}

/// Return a timestamp value from a result row.
double fbsGetTimestamp (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->rawTimestamp.seconds;
}

/// Return a daytime value from a result row.
double fbsGetDayTime (FBSRow row, unsigned column) {
    FBCRow* fbcRow = row;
    
    return fbcRow[column]->rawDayTime;
}

/// Return a bit value size from a result row.
unsigned fbsGetBitSize (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->bit.size;
}

/// Return a bit value from a result row.
const unsigned char* fbsGetBitBytes (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->bit.bytes;
}

/// Return actual type from a ANY TYPE column in a row
FBSDatatype fbsGetAnyTypeType (FBSRow row, unsigned column) {
    FBCRow* fbcRow = row;

    return datatypeFromFBCDataTypeCode (fbcRow[column]->anyType.type);
}

/// Tests if an ANY TYPE value from a result row is null
bool fbsAnyTypeIsNull (FBSRow row, unsigned column) {
    FBCRow* fbcRow = row;

    return fbcRow[column]->anyType.column == NULL;
}

/// Return an ANY TYPE boolean value from a result row.
bool fbsGetAnyTypeBoolean (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->boolean != 0;
}

/// Return an ANY TYPE tiny integer value from a result row.
long long fbsGetAnyTypeTinyInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->tinyInteger;
}

/// Return an ANY TYPE short integer value from a result row.
long long fbsGetAnyTypeShortInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->shortInteger;
}

/// Return an ANY TYPE integer value from a result row.
long long fbsGetAnyTypeInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->integer;
}

/// Return an ANY TYPE long integer value from a result row.
long long fbsGetAnyTypeLongInteger (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->longInteger;
}

/// Return an ANY TYPE numeric value from a result row.
double fbsGetAnyTypeNumeric (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->numeric;
}

/// Return an ANY TYPE real value from a result row.
double fbsGetAnyTypeReal (FBSRow row, unsigned column) {
    FBCRow* fbcRow = row;

    return fbcRow[column]->anyType.column->real;
}

/// Return an ANY TYPE decimal value from a result row.
double fbsGetAnyTypeDecimal (FBSRow row, unsigned column) {
    FBCRow* fbcRow = row;

    return fbcRow[column]->anyType.column->decimal;
}

/// Return scale of an ANY  TYPE value from a result row.
long fbsGetAnyTypeScale (FBSResult result, FBSRow row, unsigned column) {
    FBCRow* fbcRow = row;
    const FBCDatatypeMetaData* datatypeMetadata = fbcmdDatatypeMetaDataAtIndex (result, column);
    FBCDatatypeMetaData* anytypeMetadata = fbcdmdAnyTypeMetaData (datatypeMetadata, fbcRow[column]);
    long scale = fbcdmdScale (anytypeMetadata);

    fbcdmdRelease (anytypeMetadata);

    return scale;
}

/// Return an ANY TYPE character value from a result row.
const char* fbsGetAnyTypeCharacter (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->character;
}

/// Return an ANY TYPE blob handle from a result row
const char* fbsGetAnyTypeBlobHandle (FBSRow row, unsigned column, unsigned* size) {
	FBCRow* fbcRow = row;

	*size = fbcrLOBSize (&fbcRow[column]->anyType.column->blob);
	return fbcRow[column]->anyType.column->blob.handleAsString;
}

/// Return an ANY TYPE timestamp value from a result row.
double fbsGetAnyTypeTimestamp (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->rawTimestamp.seconds;
}

/// Return an ANY TYPE bit value size from a result row.
unsigned fbsGetAnyTypeBitSize (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->bit.size;
}

/// Return an ANY TYPE bit value from a result row.
const unsigned char* fbsGetAnyTypeBitBytes (FBSRow row, unsigned column) {
	FBCRow* fbcRow = row;

	return fbcRow[column]->anyType.column->bit.bytes;
}

/// Return blob data from a blob handle
const void* fbsGetBlobData (FBSConnection connection, const char* handleString) {
	FBCBlobHandle* handle = fbcbhCreate (handleString);
	const void* data = fbcdcReadBLOB (connection, handle);

	fbcbhRelease (handle);
	return data;
}

/// Release blob data returned from `fbsGetBlobData`
void fbsReleaseBlobData (const void* _Nonnull data) {
    fbcdcReleaseLOB ((void*)data);
}

/// Create a blob handle from data
FBSBlob fbsCreateBlobHandle (const void* data, unsigned size, FBSConnection connection) {
	FBCDatabaseConnection* databaseConnection = connection;

	return fbcdcWriteBLOB (databaseConnection, data, size);	
}

/// Get handel string from blob handle
const char* fbsGetBlobHandleString (FBSBlob blob) {
	FBCBlobHandle* blobHandle = blob;

	return fbcbhHandleAsChar (blobHandle);
}

/// Release a blob handle
void fbsReleaseBlobHandle (FBSBlob blob) {
	FBCBlobHandle* blobHandle = blob;

	fbcbhRelease (blobHandle);
}

/// Fetch message from a result set
const char* fbsFetchMessage (FBSResult result) {
	FBCMetaData* metadata = result;
	const char* row = fbcmdMessage (metadata);

	if (row == NULL) {
		return NULL;
	} else {
		return row;
	}
}
