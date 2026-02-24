WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CASE 
            WHEN Reputation < 100 THEN 'Novice'
            WHEN Reputation BETWEEN 100 AND 1000 THEN 'Intermediate'
            ELSE 'Expert'
        END AS ReputationLevel
    FROM Users
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year'
),
PostVotes AS (
    SELECT 
        v.PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Votes v
    GROUP BY v.PostId
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        STRING_AGG(ht.Name, ', ') AS HistoryTypes,
        MAX(ph.CreationDate) AS LastUpdated
    FROM PostHistory ph
    JOIN PostHistoryTypes ht ON ph.PostHistoryTypeId = ht.Id
    GROUP BY ph.PostId
),
QualifiedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ur.ReputationLevel,
        ur.Reputation
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    WHERE ur.ReputationLevel = 'Expert'
),
FinalPostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(phd.HistoryTypes, 'None') AS HistoryTypes,
        CASE 
            WHEN p.Score > 0 THEN 'Positive'
            WHEN p.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment,
        u.DisplayName AS PostOwner,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC) AS OverallRank
    FROM Posts p
    LEFT JOIN PostVotes v ON p.Id = v.PostId
    LEFT JOIN PostHistoryDetails phd ON p.Id = phd.PostId
    JOIN QualifiedUsers u ON p.OwnerUserId = u.Id
)
SELECT 
    fpa.PostId,
    fpa.Title,
    fpa.UpVotes,
    fpa.DownVotes,
    fpa.HistoryTypes,
    fpa.PostSentiment,
    fpa.OverallRank,
    CASE 
        WHEN fpa.OverallRank <= 10 THEN 'Top Performer'
        WHEN fpa.OverallRank <= 50 THEN 'Mid Tier Performer'
        ELSE 'Lesser Known'
    END AS PerformanceTier
FROM FinalPostAnalytics fpa
WHERE fpa.UpVotes - fpa.DownVotes > 10
ORDER BY fpa.OverallRank
FETCH FIRST 100 ROWS ONLY;