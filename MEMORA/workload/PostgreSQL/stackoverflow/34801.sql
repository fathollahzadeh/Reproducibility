
WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS RevisionNumber
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (1, 4, 10)  
),
UserVoteStatistics AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(CASE WHEN v.VoteTypeId = 4 THEN 1 END) AS OffensiveVotes
    FROM 
        Votes v
    GROUP BY 
        v.UserId
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownvotes,
        COUNT(c.Id) AS CommentCount,
        COUNT(ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId, p.CreationDate
),
UserBadgeCounts AS (
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
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.TotalBountyAmount,
    ps.TotalUpvotes,
    ps.TotalDownvotes,
    ps.CommentCount,
    ps.CloseCount,
    u.DisplayName AS OwnerDisplayName,
    ubc.BadgeCount AS OwnerBadgeCount,
    ubc.GoldBadges AS OwnerGoldBadges,
    ubc.SilverBadges AS OwnerSilverBadges,
    ubc.BronzeBadges AS OwnerBronzeBadges,
    ups.TotalVotes AS OwnerTotalVotes,
    ups.UpVotes AS OwnerUpVotes,
    ups.DownVotes AS OwnerDownVotes,
    ups.OffensiveVotes AS OwnerOffensiveVotes
FROM 
    PostStats ps
JOIN 
    Users u ON ps.OwnerUserId = u.Id
JOIN 
    UserBadgeCounts ubc ON u.Id = ubc.UserId
JOIN 
    UserVoteStatistics ups ON u.Id = ups.UserId
WHERE 
    (ps.TotalUpvotes - ps.TotalDownvotes) > 0  
ORDER BY 
    ps.TotalBountyAmount DESC, ps.CommentCount DESC, ps.CloseCount ASC
LIMIT 10;
