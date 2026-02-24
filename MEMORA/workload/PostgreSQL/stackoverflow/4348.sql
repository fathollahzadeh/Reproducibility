WITH RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT V.UserId) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 6) 
    WHERE 
        P.CreationDate > cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        VoteCount,
        RANK() OVER (PARTITION BY OwnerDisplayName ORDER BY Score DESC, ViewCount DESC) AS Rank
    FROM 
        RecentPosts
),
PostBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS Badges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    T.Title,
    T.CreationDate,
    T.Score,
    T.ViewCount,
    T.OwnerDisplayName,
    COALESCE(PB.Badges, 'No Badges') AS OwnerBadges,
    T.CommentCount,
    T.VoteCount
FROM 
    TopPosts T
LEFT JOIN 
    PostBadges PB ON T.OwnerDisplayName = (SELECT DisplayName FROM Users WHERE Id = PB.UserId)
WHERE 
    T.Rank <= 5 
ORDER BY 
    T.Score DESC, 
    T.ViewCount DESC;