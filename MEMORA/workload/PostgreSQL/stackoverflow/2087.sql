WITH UserVotes AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id,
        U.DisplayName
), PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P 
    WHERE 
        P.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), PopularPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        PS.AnswerCount,
        PS.CommentCount,
        PS.Rank
    FROM 
        PostStatistics PS
    WHERE 
        PS.Rank <= 10
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    UV.UserId,
    UV.DisplayName,
    UP.PostId,
    UP.Title,
    UP.ViewCount,
    UP.AnswerCount,
    UP.CommentCount,
    UB.GoldBadges,
    UB.SilverBadges,
    UB.BronzeBadges,
    COALESCE(UV.UpVotes, 0) AS UpVotes,
    COALESCE(UV.DownVotes, 0) AS DownVotes,
    (UP.ViewCount - COALESCE(UV.DownVotes, 0)) * 1.0 / NULLIF(UP.CommentCount + 1, 0) AS EngagementScore
FROM 
    UserVotes UV
FULL OUTER JOIN 
    PopularPosts UP ON UV.UserId = UP.PostId
LEFT JOIN 
    UserBadges UB ON UV.UserId = UB.UserId
ORDER BY 
    EngagementScore DESC, UP.ViewCount DESC;