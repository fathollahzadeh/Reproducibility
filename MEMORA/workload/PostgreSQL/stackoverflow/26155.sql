
WITH PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Score,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        STRING_AGG(DISTINCT t.TagName, ', ') AS TagsList,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        p.OwnerUserId  -- Added to GROUP BY
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        LATERAL (SELECT UNNEST(STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><')) AS TagName) t ON TRUE
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.AnswerCount, p.CommentCount, p.Score, 
        u.DisplayName, u.Reputation, p.OwnerUserId  -- Updated GROUP BY clause
),
UserBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
        COUNT(*) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(*) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(*) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.ViewCount,
    pm.AnswerCount,
    pm.CommentCount,
    pm.Score,
    pm.UpVotes,
    pm.DownVotes,
    pm.TagsList,
    pm.OwnerDisplayName,
    pm.OwnerReputation,
    ub.BadgeNames,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    PostMetrics pm
LEFT JOIN 
    UserBadges ub ON pm.OwnerUserId = ub.UserId
ORDER BY 
    pm.Score DESC, 
    pm.ViewCount DESC
LIMIT 100;
