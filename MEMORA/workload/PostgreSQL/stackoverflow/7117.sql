WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
),
PopularPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CommentCount,
        p.LastActivityDate,
        ROW_NUMBER() OVER (ORDER BY p.CommentCount DESC, p.LastActivityDate DESC) AS ActiveRank
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1
),
FinalPostStats AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.Score,
        pp.ViewCount,
        pp.CreationDate,
        ap.CommentCount,
        ap.LastActivityDate,
        ru.DisplayName AS TopUser,
        ru.Reputation AS TopUserReputation
    FROM 
        PopularPosts pp
    LEFT JOIN 
        ActivePosts ap ON pp.PostId = ap.PostId
    LEFT JOIN 
        RankedUsers ru ON ru.Rank = 1
)
SELECT 
    fps.PostId,
    fps.Title,
    fps.Score,
    fps.ViewCount,
    fps.CommentCount,
    fps.LastActivityDate,
    fps.TopUser,
    fps.TopUserReputation
FROM 
    FinalPostStats fps
WHERE 
    fps.TopUserReputation > 5000 
ORDER BY 
    fps.Score DESC, fps.ViewCount DESC;
