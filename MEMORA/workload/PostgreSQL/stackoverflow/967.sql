
WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
),
PostInteraction AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(COUNT(Cm.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments Cm ON Cm.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= (CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId
),
ClosedPostStats AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LastClosedDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10  
    GROUP BY 
        PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    PI.PostId,
    PI.Title,
    PI.CreationDate,
    PI.CommentCount,
    PI.UpVoteCount,
    PI.DownVoteCount,
    CPS.CloseCount,
    CPS.LastClosedDate
FROM 
    UserVoteStats U
JOIN 
    PostInteraction PI ON U.UserId = PI.OwnerUserId
LEFT JOIN 
    ClosedPostStats CPS ON PI.PostId = CPS.PostId
WHERE 
    (U.UpVotes - U.DownVotes) > 10
    AND (PI.CommentCount > 5 OR PI.UpVoteCount > 20)
ORDER BY 
    U.DisplayName, PI.CreationDate DESC;
