
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3) 
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.ViewCount, p.PostTypeId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS CloseDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.PostId
),
PostWithCloseInfo AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.Rank,
        cp.CloseDate,
        (SELECT COUNT(*) FROM PostHistory WHERE PostId = rp.PostId AND PostHistoryTypeId = 16) AS CommunityOwnedCount,
        CASE 
            WHEN cp.CloseDate IS NOT NULL THEN 'Closed'
            ELSE 'Open'
        END AS PostStatus
    FROM 
        RankedPosts rp
    LEFT JOIN 
        ClosedPosts cp ON rp.PostId = cp.PostId
)
SELECT 
    pwci.PostId,
    pwci.Title,
    pwci.Score,
    pwci.ViewCount,
    pwci.Rank,
    pwci.CloseDate,
    pwci.PostStatus,
    pwci.CommunityOwnedCount,
    CASE 
        WHEN pwci.PostStatus = 'Closed' AND pwci.CommunityOwnedCount > 0 THEN 'Community Owned and Closed'
        WHEN pwci.PostStatus = 'Closed' THEN 'Closed'
        ELSE 'Active'
    END AS DetailedStatus
FROM 
    PostWithCloseInfo pwci
WHERE 
    pwci.Rank <= 5 
ORDER BY 
    pwci.Rank, pwci.Score DESC;
