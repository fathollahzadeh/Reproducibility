
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        p.CreationDate,
        p.AnswerCount,
        p.CommentCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPostHistory AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS CloseDate,
        ph.UserDisplayName AS Closer
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 
),
RecentUserScores AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id
),
PostSummary AS (
    SELECT 
        rp.Title,
        rp.ViewCount,
        ub.BadgeCount,
        cp.CloseDate,
        cp.Closer,
        rus.UpVotes,
        rus.DownVotes
    FROM 
        RankedPosts rp
    JOIN 
        UserBadges ub ON rp.OwnerUserId = ub.UserId
    LEFT JOIN 
        ClosedPostHistory cp ON rp.PostId = cp.ClosedPostId
    JOIN 
        RecentUserScores rus ON rp.OwnerUserId = rus.UserId
    WHERE 
        rp.rn = 1 
)
SELECT 
    ps.Title,
    ps.ViewCount,
    ps.BadgeCount,
    ps.CloseDate,
    ps.Closer,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    CASE 
        WHEN ps.CloseDate IS NOT NULL 
        THEN 'Closed' 
        ELSE 'Active' 
    END AS PostStatus
FROM 
    PostSummary ps
ORDER BY 
    ps.ViewCount DESC
FETCH FIRST 50 ROWS ONLY;
