
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= (DATE '2024-10-01' - INTERVAL '1 year')
        AND p.ViewCount > 100
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    pu.DisplayName AS UserName,
    COUNT(rp.PostId) AS NumberOfTopPosts,
    SUM(COALESCE(pv.UpVotes, 0)) AS TotalUpVotes,
    SUM(COALESCE(pv.DownVotes, 0)) AS TotalDownVotes,
    SUM(COALESCE(pu.GoldBadges, 0)) AS TotalGoldBadges,
    SUM(COALESCE(pu.SilverBadges, 0)) AS TotalSilverBadges,
    SUM(COALESCE(pu.BronzeBadges, 0)) AS TotalBronzeBadges,
    STRING_AGG(DISTINCT rp.Tags, ', ') AS DistinctTags
FROM 
    RankedPosts rp
JOIN 
    TopUsers pu ON rp.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = pu.UserId)
LEFT JOIN 
    PostVotes pv ON rp.PostId = pv.PostId
GROUP BY 
    pu.DisplayName
HAVING 
    COUNT(rp.PostId) > 5
ORDER BY 
    NumberOfTopPosts DESC, TotalUpVotes - TotalDownVotes DESC
LIMIT 10;
