
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.ViewCount DESC) AS ScoreRank,
        COALESCE(NULLIF(p.Title, ''), '(No Title)') AS DisplayTitle,
        ARRAY(SELECT DISTINCT UNNEST(string_to_array(p.Tags, '>')) ORDER BY 1) AS TagList
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year' AND
        p.ViewCount IS NOT NULL
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldCount,  
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverCount, 
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeCount  
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldCount, 0) AS GoldCount,
        COALESCE(ub.SilverCount, 0) AS SilverCount,
        COALESCE(ub.BronzeCount, 0) AS BronzeCount,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.LastAccessDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '30 days'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.ViewCount,
        rp.Score,
        rp.DisplayTitle,
        rp.TagList,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        CASE 
            WHEN u.Reputation >= 1000 THEN 'High Reputation'
            WHEN u.Reputation < 1000 AND u.Reputation > 100 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.ScoreRank <= 5  
),
FinalOutput AS (
    SELECT 
        fp.DisplayTitle, 
        fp.ViewCount, 
        fp.Score, 
        fp.OwnerDisplayName, 
        fp.OwnerReputation,
        fp.ReputationCategory, 
        fp.TagList,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes  
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        Comments c ON fp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON fp.PostId = v.PostId
    GROUP BY 
        fp.DisplayTitle, 
        fp.ViewCount, 
        fp.Score,
        fp.OwnerDisplayName, 
        fp.OwnerReputation,
        fp.ReputationCategory, 
        fp.TagList
)
SELECT
    fo.DisplayTitle,
    fo.ViewCount,
    fo.Score,
    fo.OwnerDisplayName,
    fo.OwnerReputation,
    fo.ReputationCategory,
    fo.TagList,
    fo.CommentCount,
    fo.TotalUpVotes
FROM 
    FinalOutput fo
WHERE 
    fo.CommentCount > (SELECT AVG(CommentCount) FROM FinalOutput)  
ORDER BY 
    fo.Score DESC, 
    fo.ViewCount DESC  
LIMIT 100;
