
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(co.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, u.DisplayName, p.OwnerUserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    WHERE 
        b.Date > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
    GROUP BY 
        b.UserId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        STRING_AGG(ph.Comment, ', ') AS Comments
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '6 months'
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    rb.BadgeNames,
    phd.Comments AS PostHistoryComments,
    CASE 
        WHEN COUNT(rp.RankByScore) > 1 THEN 'Multiple Posts'
        ELSE 'Single Post'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    RecentBadges rb ON rp.OwnerUserId = rb.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
GROUP BY 
    rp.PostId, rp.Title, rp.Score, rp.ViewCount, rp.OwnerDisplayName, 
    rp.CommentCount, rp.UpVoteCount, rp.DownVoteCount, rb.BadgeNames, phd.Comments
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 100;
