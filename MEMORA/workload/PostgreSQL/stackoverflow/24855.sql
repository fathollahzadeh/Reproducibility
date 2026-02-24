
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS QuestionCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        ph.CreationDate AS CloseDate,
        ph.UserId AS CloserUserId,
        pr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        CloseReasonTypes pr ON (ph.Comment::jsonb ->> 'CloseReasonId')::int = pr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 
)

SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.UpVotes,
    us.DownVotes,
    us.BadgeCount,
    us.QuestionCount,
    rp.PostId,
    rp.Title,
    rp.CreationDate AS QuestionDate,
    COALESCE(cp.CloseDate, NULL) AS ClosedDate,
    COALESCE(cp.CloseReason, 'Not Closed') AS ClosureReason,
    CASE 
        WHEN us.Reputation > 1000 THEN 'Established User'
        WHEN us.Reputation BETWEEN 500 AND 1000 THEN 'Growing User'
        ELSE 'New User'
    END AS UserType,
    CASE 
        WHEN cp.ClosedPostId IS NOT NULL THEN 'Yes'
        ELSE 'No'
    END AS WasClosed
FROM 
    UserStats us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.ClosedPostId
WHERE 
    us.Reputation > 0
ORDER BY 
    us.Reputation DESC, 
    rp.Score DESC NULLS LAST
LIMIT 50;
