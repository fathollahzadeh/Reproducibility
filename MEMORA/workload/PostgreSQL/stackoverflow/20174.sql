
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId, p.PostTypeId
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        p.Id AS PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (12, 13) THEN 1 END) AS DeletionCount
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title, 
        rp.Score,
        us.DisplayName,
        phs.ClosedDate,
        phs.ReopenedDate,
        COALESCE(rp.TotalUpvotes - rp.TotalDownvotes, 0) AS NetVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserStatistics us ON rp.OwnerUserId = us.UserId
    LEFT JOIN 
        PostHistoryStats phs ON rp.PostId = phs.PostId
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.DisplayName,
    tp.ClosedDate,
    tp.ReopenedDate,
    tp.NetVotes,
    CASE 
        WHEN tp.ClosedDate IS NOT NULL AND tp.ReopenedDate IS NULL THEN 'Closed'
        WHEN tp.ReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    CONCAT('Post Title: ', tp.Title, ' | Score: ', tp.Score, ' | Owner: ', tp.DisplayName) AS PostSummary
FROM 
    TopPosts tp
ORDER BY 
    tp.NetVotes DESC, tp.Score DESC;
