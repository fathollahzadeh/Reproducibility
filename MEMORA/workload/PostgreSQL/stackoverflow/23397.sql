
WITH RecursivePostHistory AS (
    SELECT 
        ph.Id, 
        ph.PostId, 
        ph.CreationDate,
        ph.UserId, 
        ph.UserDisplayName, 
        ph.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.UserId IS NOT NULL
), 
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS TotalComments,
        COUNT(DISTINCT v.UserId) AS TotalVotes,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
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
PostWithLatestHistory AS (
    SELECT 
        rp.*,
        COALESCE(rh.UserDisplayName, 'Unknown') AS LastEditor,
        CASE 
            WHEN rh.PostHistoryTypeId IN (10, 11) THEN 'Closed'
            WHEN rh.PostHistoryTypeId IS NULL THEN 'Active'
            ELSE 'Edited'
        END AS PostStatus
    FROM 
        RecentPosts rp
    LEFT JOIN 
        RecursivePostHistory rh ON rp.PostId = rh.PostId AND rh.HistoryRank = 1
)

SELECT 
    pwlh.PostId,
    pwlh.Title,
    pwlh.OwnerUserId,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    pwlh.TotalComments,
    pwlh.TotalVotes,
    pwlh.UpVotes,
    pwlh.DownVotes,
    pwlh.LastEditor,
    pwlh.PostStatus,
    CASE 
        WHEN pwlh.TotalVotes > 0 THEN ROUND((1.0 * pwlh.UpVotes / pwlh.TotalVotes) * 100, 2)::TEXT || '%' 
        ELSE 'N/A'
    END AS VoteRatio
FROM 
    PostWithLatestHistory pwlh
LEFT JOIN 
    UserBadges ub ON pwlh.OwnerUserId = ub.UserId
ORDER BY 
    pwlh.TotalVotes DESC, 
    pwlh.Title;
