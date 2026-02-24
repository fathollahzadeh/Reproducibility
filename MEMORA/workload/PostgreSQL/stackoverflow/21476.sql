WITH UserBadgeCounts AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        COALESCE(c.CreationDate, p.CreationDate) AS PostCreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2023-01-01'
),
VoteSummary AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pht.Name, ', ') AS HistoryTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ud.GoldBadges,
    ud.SilverBadges,
    ud.BronzeBadges,
    pd.PostId,
    pd.Score,
    vs.UpVotes,
    vs.DownVotes,
    vs.TotalVotes,
    COALESCE(ps.LastEditDate, '2023-01-01 00:00:00') AS LastEditDate,
    COALESCE(ps.HistoryTypes, 'No History') AS HistoryTypes,
    CASE 
        WHEN ud.GoldBadges > 0 THEN 'Gold'
        WHEN ud.SilverBadges > 0 THEN 'Silver'
        WHEN ud.BronzeBadges > 0 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeTier
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ud ON u.Id = ud.UserId
JOIN 
    PostDetails pd ON u.Id = pd.OwnerUserId
LEFT JOIN 
    VoteSummary vs ON pd.PostId = vs.PostId
LEFT JOIN 
    PostHistoryStats ps ON pd.PostId = ps.PostId
WHERE 
    (ud.GoldBadges + ud.SilverBadges + ud.BronzeBadges) > 0
    AND pd.UserPostRank = 1
ORDER BY 
    u.Reputation DESC, 
    pd.Score DESC
LIMIT 100 OFFSET 0;
