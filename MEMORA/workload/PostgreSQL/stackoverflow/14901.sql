WITH Benchmark AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (24, 25) THEN 1 END) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 12 THEN 1 END) AS DeleteCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 13 THEN 1 END) AS UndeleteCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 14 THEN 1 END) AS LockCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 15 THEN 1 END) AS UnlockCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 19 THEN 1 END) AS ProtectCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 20 THEN 1 END) AS UnprotectCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (1, 4, 5) THEN 1 END) AS TitleOrBodyEditCount,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        COUNT(DISTINCT V.UserId) AS UniqueVoters,
        AVG(U.Reputation) AS AverageUserReputation
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        Votes V ON V.PostId = P.Id
    JOIN 
        Users U ON V.UserId = U.Id
    GROUP BY 
        PH.PostId
)
SELECT 
    PostId,
    CloseCount,
    ReopenCount,
    EditCount,
    DeleteCount,
    UndeleteCount,
    LockCount,
    UnlockCount,
    ProtectCount,
    UnprotectCount,
    TitleOrBodyEditCount,
    QuestionCount,
    AnswerCount,
    UniqueVoters,
    AverageUserReputation
FROM 
    Benchmark
ORDER BY 
    PostId;
