WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(DISTINCT B.Name, ', ') AS BadgeNames
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),

TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        P.Tags,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COALESCE( (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id), 0) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.ViewCount DESC
    LIMIT 10
),

VoteCounts AS (
    SELECT 
        V.PostId,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(V.Id) AS TotalVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)

SELECT 
    UpP.Title AS PostTitle,
    UpP.OwnerDisplayName,
    UpP.ViewCount AS PostViews,
    UpP.Score AS PostScore,
    UpV.UpVotes,
    UpV.DownVotes,
    UpV.TotalVotes,
    UB.BadgeCount,
    UB.BadgeNames
FROM 
    TopPosts UpP
LEFT JOIN 
    VoteCounts UpV ON UpP.PostId = UpV.PostId
LEFT JOIN 
    UserBadges UB ON UpP.OwnerDisplayName = UB.DisplayName
WHERE 
    UpP.CommentCount > 5
ORDER BY 
    UpP.Score DESC, UpVotes DESC;