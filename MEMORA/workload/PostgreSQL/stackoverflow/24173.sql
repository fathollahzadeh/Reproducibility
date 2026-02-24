WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate ASC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '1 year'
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        AVG(b.Class) AS AvgBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
PostVoteDetails AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), 
CommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
), 
PostHistoryDetails AS (
    SELECT 
        PostId,
        MAX(CASE WHEN PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS IsClosedOrReopened
    FROM 
        PostHistory
    GROUP BY 
        PostId
)

SELECT 
    p.PostId,
    p.Title,
    p.Score,
    COALESCE(pb.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(pb.AvgBadgeClass, 0) AS UserAvgBadgeClass,
    COALESCE(v.UpVotes, 0) AS UpVoteTotal,
    COALESCE(v.DownVotes, 0) AS DownVoteTotal,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    ph.IsClosedOrReopened,
    CASE 
        WHEN ph.IsClosedOrReopened = 1 THEN 'Closed or Reopened'
        ELSE 'Active'
    END AS PostStatus,
    CASE 
        WHEN p.Score IS NULL THEN 'No Score' 
        WHEN p.Score < 0 THEN 'Negative Score' 
        ELSE 'Positive Score' 
    END AS ScoreStatus
FROM 
    RankedPosts p
LEFT JOIN 
    UserBadges pb ON p.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = pb.UserId)
LEFT JOIN 
    PostVoteDetails v ON p.PostId = v.PostId
LEFT JOIN 
    CommentCounts c ON p.PostId = c.PostId
LEFT JOIN 
    PostHistoryDetails ph ON p.PostId = ph.PostId
WHERE 
    p.PostRank <= 5
ORDER BY 
    p.Score DESC, p.CreationDate ASC;