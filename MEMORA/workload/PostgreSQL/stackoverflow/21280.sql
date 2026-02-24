WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankByDate,
        DENSE_RANK() OVER (ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        COALESCE(NULLIF(SUBSTRING(p.Body, 1, 100), ''), 'No content available') AS BodySnippet
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
BadgeAndVoteCounts AS (
    SELECT 
        u.Id AS UserId, 
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes,
        COUNT(*) AS HistoryCount,
        MAX(ph.CreationDate) AS LastChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    u.DisplayName AS OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    COALESCE(bvc.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(bvc.UpVoteCount, 0) AS UpVoteCount,
    COALESCE(bvc.DownVoteCount, 0) AS DownVoteCount,
    rp.CommentCount,
    COALESCE(phd.ChangeTypes, 'No changes recorded') AS RecentChanges,
    phd.LastChangeDate
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN 
    BadgeAndVoteCounts bvc ON u.Id = bvc.UserId
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    (rp.RankByDate = 1 OR rp.RankByScore <= 10)
    AND (bvc.UpVoteCount - bvc.DownVoteCount > 5 OR bvc.BadgeCount > 3)
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC
LIMIT 100;