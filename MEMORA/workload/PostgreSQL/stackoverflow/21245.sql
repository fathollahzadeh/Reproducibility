WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate > cast('2024-10-01' as date) - INTERVAL '365 days'
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
LastActiveUserPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.LastActivityDate,
        u.DisplayName,
        u.Reputation,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, u.DisplayName, u.Reputation
    HAVING 
        MAX(p.LastActivityDate) >= cast('2024-10-01' as date) - INTERVAL '30 days'
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 12 THEN ph.CreationDate END) AS DeletedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    au.DisplayName AS OwnerDisplayName,
    au.Reputation AS OwnerReputation,
    la.LastActivityDate,
    la.CommentCount,
    ph.ClosedDate,
    ph.DeletedDate,
    CASE 
        WHEN ph.ClosedDate IS NOT NULL AND ph.DeletedDate IS NULL THEN 'Closed' 
        WHEN ph.DeletedDate IS NOT NULL THEN 'Deleted'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN au.UpvotesReceived - au.DownvotesReceived > 0 THEN 'More Upvotes'
        WHEN au.UpvotesReceived - au.DownvotesReceived < 0 THEN 'More Downvotes'
        ELSE 'Equal Upvotes/Downvotes'
    END AS VoteBalance,
    CASE 
        WHEN au.Reputation BETWEEN 0 AND 100 THEN 'Newbie'
        WHEN au.Reputation BETWEEN 101 AND 1000 THEN 'Intermediate'
        WHEN au.Reputation > 1000 THEN 'Experienced'
        ELSE 'Unknown'
    END AS UserLevel
FROM 
    RankedPosts rp
JOIN 
    ActiveUsers au ON rp.OwnerUserId = au.UserId
JOIN 
    LastActiveUserPosts la ON rp.PostId = la.PostId
LEFT JOIN 
    PostHistoryInfo ph ON rp.PostId = ph.PostId
WHERE 
    rp.Rank = 1 AND 
    (au.Reputation > 100 OR la.CommentCount > 0)
ORDER BY 
    au.Reputation DESC,
    la.CommentCount DESC;