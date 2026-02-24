
WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        p.CreationDate,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostVoteSummary AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(c.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    INNER JOIN 
        CloseReasonTypes c ON CAST(ph.Comment AS int) = c.Id
    WHERE 
        ph.PostHistoryTypeId = 10  
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    u.DisplayName AS User,
    up.Title AS RecentQuestion,
    up.Score AS QuestionScore,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    COALESCE(ps.UpVotes, 0) AS TotalUpVotes,
    COALESCE(ps.DownVotes, 0) AS TotalDownVotes,
    cp.CloseReasons AS CloseReasonsSummary,
    CASE 
        WHEN cp.CloseReasons IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    Users u
JOIN 
    UserBadges ub ON u.Id = ub.UserId
JOIN 
    RecursivePostCTE up ON u.Id = up.OwnerUserId AND up.rn = 1
LEFT JOIN 
    PostVoteSummary ps ON up.PostId = ps.PostId
LEFT JOIN 
    ClosedPosts cp ON up.PostId = cp.PostId
WHERE 
    u.Reputation > 1000  
ORDER BY 
    u.Reputation DESC, up.CreationDate DESC;
