WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
UserVoteStats AS (
    SELECT 
        v.UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
RecentBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        RANK() OVER (PARTITION BY b.UserId ORDER BY b.Date DESC) AS BadgeRank
    FROM 
        Badges b
    WHERE 
        b.Date >= cast('2024-10-01' as date) - INTERVAL '1 year'
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        STRING_AGG(ph.Comment, '; ') AS EditComments,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6, 24) 
    GROUP BY 
        ph.PostId, ph.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(uvs.UpVotes, 0) AS UserUpVotes,
    COALESCE(uvs.DownVotes, 0) AS UserDownVotes,
    COALESCE(b.BadgeCount, 0) AS UserBadgeCount,
    phd.EditComments,
    phd.LastEditDate,
    CASE 
        WHEN rp.Rank = 1 THEN 'Most Recent'
        ELSE 'Other'
    END AS PostRank
FROM 
    RankedPosts rp
LEFT JOIN 
    UserVoteStats uvs ON uvs.UserId = rp.PostId 
LEFT JOIN 
    (SELECT 
        UserId, COUNT(*) AS BadgeCount 
     FROM 
        RecentBadges 
     WHERE 
        BadgeRank = 1 
     GROUP BY 
        UserId) AS b ON b.UserId = rp.PostId 
LEFT JOIN 
    PostHistoryDetails phd ON phd.PostId = rp.PostId
WHERE 
    rp.Rank <= 5 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;