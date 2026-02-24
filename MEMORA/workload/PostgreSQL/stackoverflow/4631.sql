WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 
),
UserVotes AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
),
ActiveUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        U.LastAccessDate
    FROM 
        Users U
    WHERE 
        U.LastAccessDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(C.Id) AS CommentCount
    FROM 
        Comments C
    GROUP BY 
        C.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    AU.DisplayName AS Author,
    COALESCE(UP.UpVotes, 0) AS TotalUpVotes,
    COALESCE(DN.DownVotes, 0) AS TotalDownVotes,
    COALESCE(PC.CommentCount, 0) AS TotalComments,
    CASE 
        WHEN RP.PostRank = 1 THEN 'Latest Post'
        ELSE 'Older Post' 
    END AS PostStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    UserVotes UP ON RP.PostId = UP.PostId
LEFT JOIN 
    UserVotes DN ON RP.PostId = DN.PostId
JOIN 
    ActiveUsers AU ON RP.OwnerUserId = AU.Id
LEFT JOIN 
    PostComments PC ON RP.PostId = PC.PostId
WHERE 
    RP.PostRank <= 5 
ORDER BY 
    RP.OwnerUserId, RP.CreationDate DESC;