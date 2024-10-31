#ifndef __CFRONTBASE_SUPPORT_H__
#define __CFRONTBASE_SUPPORT_H__

#include <stdio.h>
#include <stdbool.h>
#include <FBCAccess/FBCAccess.h>

#if __has_feature(assume_nonnull)
#pragma clang assume_nonnull begin
#endif

typedef void* FBSConnection;
typedef void* FBSResult;
typedef void* FBSRow;
typedef void* FBSBlob;

typedef enum FBSDatatype {
   FBS_PrimaryKey,
   FBS_Boolean,
   FBS_Integer,
   FBS_SmallInteger,
   FBS_Float,
   FBS_Real,
   FBS_Double,
   FBS_Numeric,
   FBS_Decimal,
   FBS_Character,
   FBS_VCharacter,
   FBS_Bit,
   FBS_VBit,
   FBS_Date,
   FBS_Time,
   FBS_TimeTZ,
   FBS_Timestamp,
   FBS_TimestampTZ,
   FBS_YearMonth,
   FBS_DayTime,
   FBS_CLOB,
   FBS_BLOB,
   FBS_TinyInteger,
   FBS_LongInteger,
   FBS_CircaDate,
   FBS_AnyType,
   FBS_Undecided
} FBSDatatype;

typedef struct FBSColumnInfo {
	const char* tableName;
	const char* labelName;
	FBSDatatype datatype;
    bool isNullable;
} FBSColumnInfo;

/// Open a connection through FBExec on a host, and create a session.
/// Any returned FBSConnection MUST be deallocated using fbsCloseConnection().
/// If NULL is returned, *errorMessage will contain a message.
FBSConnection _Nullable fbsConnectDatabaseOnHost (const char* databaseName,
                                                  const char* hostName,
                                                  const char* _Nullable databasePassword,
                                                  const char* username,
                                                  const char* password,
                                                  const char* defaultSessionName,
                                                  const char* operatingSystemUser,
                                                  const char* _Nullable * _Nullable errorMessage);

/// Open a connection at a port on a host, and create a session.
/// Any returned FBSConnection MUST be deallocated using fbsCloseConnection().
/// If NULL is returned, *errorMessage will contain a message.
FBSConnection _Nullable fbsConnectDatabaseOnPort (const char* hostName,
                                                  unsigned port,
                                                  const char* _Nullable databasePassword,
                                                  const char* username,
                                                  const char* password,
                                                  const char* defaultSessionName,
                                                  const char* operatingSystemUser,
                                                  const char* _Nullable * _Nullable errorMessage);

/// Open a connection to a local database file, and create a session.
/// Any returned FBSConnection MUST be deallocated using fbsClose().
/// If NULL is returned, *errorMessage will contain a message.
FBSConnection _Nullable fbsConnectDatabaseAtPath (const char* databaseName,
                                                  const char* pathName,
                                                  const char* _Nullable databasePassword,
                                                  const char* username,
                                                  const char* password,
                                                  const char* defaultSessionName,
                                                  const char* operatingSystemUser,
                                                  const char* _Nullable * _Nullable errorMessage);

/// Close database connection, and deallocate data structures.
void fbsCloseConnection (FBSConnection connection);

/// Returns true if connection is non-null and has an active session,
/// otherwise false
bool fbsConnectionIsOpen (FBSConnection connection);

/// Create a database with the specified Frontbase URL
void fbsCreateDatabaseWithUrl (const char* url);

/// Start database with the specified Frontbase URL
void fbsStartDatabaseWithUrl (const char* url);

/// Delete a database with the specified Frontbase URL
void fbsDeleteDatabaseWithUrl (const char* url);

/// Returns the latest error message for connection
const char* fbsErrorMessage (FBSConnection connection);

/// Execute SQL
/// Any returned FBSResult MUST be deallocated using fbsCloseResult().
/// If NULL is returned, *errorMessage will contain a message.
FBSResult _Nullable fbsExecuteSQL (FBSConnection connection,
                                   const char* sql,
                                   bool autoCommit,
                                   const char* _Nullable * _Nullable errorMessage);

/// Close result set, and deallocate data structures.
void fbsCloseResult (FBSResult result);

/// Fetch a row from a result set
/// Any returned FBSRow MUST be deallocated using fbsReleaseRow().
/// If NULL is returned, there are no more rows to fetch.
FBSRow _Nullable fbsFetchRow (FBSResult result);

/// Release result row, and deallocate data structures.
void fbsReleaseRow (FBSRow row);

/// Get number of columns in result
unsigned fbsGetColumnCount (FBSResult result);

/// Get column information
const FBSColumnInfo fbsGetColumnInfoAtIndex (FBSResult result, unsigned column);

/// Tests if a value from a result row is null
bool fbsIsNull (FBSRow row, unsigned column);

/// Return a boolean value from a result row.
bool fbsGetBoolean (FBSRow row, unsigned column);

/// Return a tiny integer value from a result row.
long long fbsGetTinyInteger (FBSRow row, unsigned column);

/// Return a short integer value from a result row.
long long fbsGetShortInteger (FBSRow row, unsigned column);

/// Return a integer value from a result row.
long long fbsGetInteger (FBSRow row, unsigned column);

/// Return a long integer value from a result row.
long long fbsGetLongInteger (FBSRow row, unsigned column);

/// Return a numeric value from a result row.
double fbsGetNumeric (FBSRow row, unsigned column);

/// Return a real value from a result row.
double fbsGetReal (FBSRow row, unsigned column);

/// Return a decimal value from a result row.
double fbsGetDecimal (FBSRow row, unsigned column);

/// Return scale of value from a result row.
long fbsGetScale (FBSResult result, FBSRow row, unsigned column);

/// Return a character value from a result row.
const char* fbsGetCharacter (FBSRow row, unsigned column);

/// Return a blob handle from a result row
const char* fbsGetBlobHandle (FBSRow row, unsigned column, unsigned* size);

/// Return a timestamp value from a result row.
double fbsGetTimestamp (FBSRow row, unsigned column);

/// Return a daytime value from a result row.
double fbsGetDayTime (FBSRow row, unsigned column);

/// Return a bit value size from a result row.
unsigned fbsGetBitSize (FBSRow row, unsigned column);

/// Return a bit value from a result row.
const unsigned char* fbsGetBitBytes (FBSRow row, unsigned column);

/// Return actual type from an ANY TYPE column in a row
FBSDatatype fbsGetAnyTypeType (FBSRow row, unsigned column);

/// Tests if an ANY TYPE value from a result row is null
bool fbsAnyTypeIsNull (FBSRow row, unsigned column);

/// Return an ANY TYPE boolean value from a result row.
bool fbsGetAnyTypeBoolean (FBSRow row, unsigned column);

/// Return an ANY TYPE tiny integer value from a result row.
long long fbsGetAnyTypeTinyInteger (FBSRow row, unsigned column);

/// Return an ANY TYPE short integer value from a result row.
long long fbsGetAnyTypeShortInteger (FBSRow row, unsigned column);

/// Return an ANY TYPE integer value from a result row.
long long fbsGetAnyTypeInteger (FBSRow row, unsigned column);

/// Return an ANY TYPE long integer value from a result row.
long long fbsGetAnyTypeLongInteger (FBSRow row, unsigned column);

/// Return an ANY TYPE numeric value from a result row.
double fbsGetAnyTypeNumeric (FBSRow row, unsigned column);

/// Return an ANY TYPE real value from a result row.
double fbsGetAnyTypeReal (FBSRow row, unsigned column);

/// Return an ANY TYPE decimal value from a result row.
double fbsGetAnyTypeDecimal (FBSRow row, unsigned column);

/// Return scale of an ANY  TYPE value from a result row.
long fbsGetAnyTypeScale (FBSResult result, FBSRow row, unsigned column);

/// Return an ANY TYPE character value from a result row.
const char* fbsGetAnyTypeCharacter (FBSRow row, unsigned column);

/// Return an ANY TYPE blob handle from a result row
const char* fbsGetAnyTypeBlobHandle (FBSRow row, unsigned column, unsigned* size);

/// Return an ANY TYPE timestamp value from a result row.
double fbsGetAnyTypeTimestamp (FBSRow row, unsigned column);

/// Return an ANY TYPE bit value size from a result row.
unsigned fbsGetAnyTypeBitSize (FBSRow row, unsigned column);

/// Return an ANY TYPE bit value from a result row.
const unsigned char* fbsGetAnyTypeBitBytes (FBSRow row, unsigned column);

/// Return blob data from a blob handle
const void* fbsGetBlobData (FBSConnection connection, const char* handleString);

/// Release blob data returned from `fbsGetBlobData`
void fbsReleaseBlobData (const void* data);

/// Create a blob handle from data
FBSBlob _Nullable fbsCreateBlobHandle (const void* data, unsigned size, FBSConnection connection);

/// Get handlestring from blob handle
const char* fbsGetBlobHandleString (FBSBlob blob);

/// Release a blob handle
void fbsReleaseBlobHandle (FBSBlob blob);

/// Fetch message from a result set
const char* _Nullable fbsFetchMessage (FBSResult _Nullable result);

#if __has_feature(assume_nonnull)
#pragma clang assume_nonnull end
#endif

#endif
