
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) - SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS NetVotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 
        AND P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 YEAR'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, U.DisplayName
),
RecentActivePosts AS (
    SELECT 
        P.Id, 
        P.Title, 
        MAX(C.CreationDate) AS LatestCommentDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.PostTypeId = 1
    GROUP BY 
        P.Id, P.Title
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.AnswerCount,
    RP.NetVotes,
    RAP.LatestCommentDate,
    CASE 
        WHEN RAP.LatestCommentDate IS NULL THEN 'No Comments'
        WHEN RAP.LatestCommentDate < TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 DAY' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus
FROM 
    RankedPosts RP
LEFT JOIN 
    RecentActivePosts RAP ON RP.PostId = RAP.Id
WHERE 
    RP.rn = 1
ORDER BY 
    RP.NetVotes DESC 
FETCH FIRST 10 ROWS ONLY;
