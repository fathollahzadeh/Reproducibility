
WITH RecentActivity AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.ViewCount, 
        P.CreationDate, 
        U.DisplayName AS OwnerDisplayName, 
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.LastActivityDate DESC) AS ActivityRank
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.ViewCount, P.CreationDate, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        ViewCount,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes,
        RANK() OVER (ORDER BY ViewCount DESC) AS PopularityRank
    FROM 
        RecentActivity
    WHERE 
        ActivityRank = 1
)
SELECT 
    T.Title,
    T.OwnerDisplayName,
    T.ViewCount,
    T.CommentCount,
    T.UpVotes,
    T.DownVotes,
    CASE 
        WHEN T.DownVotes > 0 THEN 'Content might be controversial'
        ELSE 'Content appears to be well-received'
    END AS Reception,
    COALESCE(PH.Comment, 'No close reason provided') AS CloseReason
FROM 
    TopPosts T
LEFT JOIN 
    PostHistory PH ON T.PostId = PH.PostId AND PH.PostHistoryTypeId = 10
WHERE 
    T.PopularityRank <= 10
ORDER BY 
    T.PopularityRank;
