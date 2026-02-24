WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS MostRecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),

PostVoteSummary AS (
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

UserContribution AS (
    SELECT 
        u.Id AS UserId,
        COUNT(p.Id) AS PostCount,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        MAX(u.Reputation) AS HighestReputation
    FROM 
        Users u 
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id
),

PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(DISTINCT pht.Name, ', ') AS ChangeTypes,
        MIN(ph.CreationDate) AS FirstChangeDate
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)

SELECT 
    rp.Title,
    rp.PostId,
    rp.CreationDate,
    rp.Score,
    pvs.UpVotes,
    pvs.DownVotes,
    pvs.TotalVotes,
    uc.PostCount,
    uc.TotalBadges,
    uc.HighestReputation,
    phd.ChangeTypes,
    phd.FirstChangeDate,
    CASE 
        WHEN rp.RankScore <= 5 THEN 'Top Posts'
        ELSE 'Other Posts'
    END AS PostCategory
FROM 
    RankedPosts rp
LEFT JOIN 
    PostVoteSummary pvs ON rp.PostId = pvs.PostId
LEFT JOIN 
    UserContribution uc ON uc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
LEFT JOIN 
    PostHistoryDetails phd ON rp.PostId = phd.PostId
WHERE 
    (rp.Score > 10 OR (phd.ChangeTypes IS NOT NULL AND rp.MostRecentRank <= 10))
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;