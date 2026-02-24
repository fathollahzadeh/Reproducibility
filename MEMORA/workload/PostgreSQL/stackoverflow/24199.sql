
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(BadgeCount, 0) AS BadgeCount,
        COALESCE(PostCount, 0) AS PostCount,
        COALESCE(CommentCount, 0) AS CommentCount,
        COALESCE(VoteCount, 0) AS VoteCount
    FROM 
        Users U
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS BadgeCount 
        FROM Badges 
        GROUP BY UserId
    ) B ON U.Id = B.UserId
    LEFT JOIN (
        SELECT OwnerUserId, COUNT(*) AS PostCount 
        FROM Posts 
        GROUP BY OwnerUserId
    ) P ON U.Id = P.OwnerUserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY UserId
    ) C ON U.Id = C.UserId
    LEFT JOIN (
        SELECT UserId, COUNT(*) AS VoteCount 
        FROM Votes 
        GROUP BY UserId
    ) V ON U.Id = V.UserId
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AcceptedAnswerId,
        COUNT(DISTINCT C.Id) AS TotalComments,
        AVG(P.Score) AS AvgPostScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.AcceptedAnswerId
),
UserPostHistory AS (
    SELECT 
        U.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        PH.UserDisplayName,
        PH.PostHistoryTypeId,
        CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11) THEN 'Close/Reopen'
            WHEN PH.PostHistoryTypeId IN (12, 13) THEN 'Delete/Undelete'
            ELSE 'Other'
        END AS HistoryType,
        ROW_NUMBER() OVER (PARTITION BY U.UserId ORDER BY PH.CreationDate DESC) AS RowNum
    FROM 
        UserStatistics U
    JOIN 
        PostHistory PH ON U.UserId = PH.UserId
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.CreationDate BETWEEN TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '2 years' AND TIMESTAMP '2024-10-01 12:34:56'
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.BadgeCount,
    P.Title AS PostTitle,
    DENSE_RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
    COUNT(DISTINCT PH.PostId) FILTER (WHERE PH.HistoryType = 'Close/Reopen') AS CloseReopenCount,
    COUNT(DISTINCT PH.PostId) FILTER (WHERE PH.HistoryType = 'Delete/Undelete') AS DeleteUndeleteCount,
    STRING_AGG(DISTINCT PH.UserDisplayName, ', ') AS RelatedUserNames
FROM 
    UserStatistics U
JOIN 
    UserPostHistory PH ON U.UserId = PH.UserId
JOIN 
    PostDetails P ON PH.PostId = P.PostId
WHERE 
    U.Reputation > 1000 AND 
    P.AvgPostScore >= 1
GROUP BY 
    U.DisplayName, U.Reputation, U.BadgeCount, P.Title
HAVING 
    COUNT(P.PostId) > 3
ORDER BY 
    U.Reputation DESC, P.Title;
