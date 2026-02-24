WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
),
RecentBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Date AS BadgeDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Users u
    JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        b.Class = 1 
),
CommentStatistics AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN c.Score > 0 THEN 1 ELSE 0 END) AS PositiveComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    CASE 
        WHEN rs.UserId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS HasRecentGoldBadge,
    cs.CommentCount,
    cs.PositiveComments,
    vs.UpVotes,
    vs.DownVotes,
    vs.TotalVotes
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rs ON rp.PostId = rs.UserId AND rs.BadgeRank = 1
LEFT JOIN 
    CommentStatistics cs ON rp.PostId = cs.PostId
LEFT JOIN 
    VoteStatistics vs ON rp.PostId = vs.PostId
WHERE 
    rp.RankByScore <= 10 
ORDER BY 
    rp.PostId;