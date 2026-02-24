WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
AggregatedVotes AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        u.DisplayName AS OwnerName,
        ab.UpVotes,
        ab.DownVotes,
        ub.TotalBadges,
        ub.HighestBadgeClass
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    LEFT JOIN 
        AggregatedVotes ab ON rp.PostId = ab.PostId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        rp.PostRank <= 5  
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.OwnerName,
    COALESCE(cd.UpVotes, 0) AS UpVotesCount,
    COALESCE(cd.DownVotes, 0) AS DownVotesCount,
    COALESCE(cd.TotalBadges, 0) AS UserBadgesCount,
    CASE 
        WHEN cd.HighestBadgeClass IS NULL THEN 'None'
        WHEN cd.HighestBadgeClass = 1 THEN 'Gold'
        WHEN cd.HighestBadgeClass = 2 THEN 'Silver'
        ELSE 'Bronze'
    END AS HighestBadge
FROM 
    CombinedData cd
ORDER BY 
    cd.OwnerName ASC, cd.PostId DESC
LIMIT 100;