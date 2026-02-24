
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(EXTRACT(EPOCH FROM (V.CreationDate - U.CreationDate)) / 3600) AS AvgHoursSinceJoin
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COALESCE(UP.AvgHoursSinceJoin, 0) AS AvgUserVoteTime
    FROM 
        Posts P
    LEFT JOIN 
        UserVoteSummary UP ON P.OwnerUserId = UP.UserId
    WHERE 
        P.CreationDate >= CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    PD.PostId,
    PD.Title,
    PD.CreationDate,
    PD.Score,
    CP.FirstClosedDate,
    PD.AvgUserVoteTime,
    CASE 
        WHEN CP.FirstClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    COALESCE(B.Name, 'No Badge') AS RecentBadge
FROM 
    PostDetails PD
LEFT JOIN 
    ClosedPosts CP ON PD.PostId = CP.PostId
LEFT JOIN 
    Badges B ON PD.PostId = B.UserId AND B.Date = (SELECT MAX(Date) FROM Badges WHERE UserId = B.UserId)
WHERE 
    PD.Score > (SELECT AVG(Score) FROM Posts) 
ORDER BY 
    PD.Score DESC, PD.CreationDate ASC
LIMIT 50 OFFSET 10;
