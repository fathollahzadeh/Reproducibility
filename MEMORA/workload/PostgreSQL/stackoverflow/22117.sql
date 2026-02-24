
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'Gold'
            WHEN Reputation >= 500 THEN 'Silver'
            WHEN Reputation >= 0 THEN 'Bronze'
            ELSE 'Negative'
        END AS ReputationCategory
    FROM Users
),

PostScoreDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(p.Score, 0) AS PostScore,
        COALESCE(votes.UpVotes, 0) AS UpVotes,
        COALESCE(votes.DownVotes, 0) AS DownVotes,
        CASE 
            WHEN COALESCE(p.Score, 0) > 0 THEN 'Positive'
            WHEN COALESCE(p.Score, 0) < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS ScoreSentiment
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes
        GROUP BY PostId
    ) votes ON p.Id = votes.PostId
),

ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        STRING_AGG(DISTINCT cr.Name, ', ') AS CloseReasons
    FROM PostHistory ph
    JOIN CloseReasonTypes cr ON CAST(ph.Comment AS int) = cr.Id
    WHERE ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY ph.PostId, ph.CreationDate
),

UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),

AggregatedData AS (
    SELECT 
        ur.UserId,
        ur.ReputationCategory,
        COUNT(DISTINCT ps.PostId) AS TotalPosts,
        SUM(ps.PostScore) AS TotalPostScore,
        SUM(ua.PostsCreated) AS PostsCreatedByOwner,
        SUM(ua.TotalViews) AS TotalViewsByOwner,
        COUNT(cp.PostId) AS ClosedPostCount
    FROM UserReputation ur
    LEFT JOIN PostScoreDetails ps ON ur.UserId = ps.PostId
    LEFT JOIN UserActivity ua ON ur.UserId = ua.UserId
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
    GROUP BY ur.UserId, ur.ReputationCategory
)

SELECT 
    ad.UserId,
    ad.ReputationCategory,
    ad.TotalPosts,
    ad.TotalPostScore,
    ad.PostsCreatedByOwner,
    ad.TotalViewsByOwner,
    ad.ClosedPostCount,
    CASE 
        WHEN ad.TotalPostScore > 0 THEN 'This user has a positive influence.'
        WHEN ad.TotalPostScore < 0 THEN 'This user has a negative influence.'
        ELSE 'This user has a neutral presence.'
    END AS InfluenceDescription
FROM AggregatedData ad
WHERE ad.TotalPosts > 5  
ORDER BY ad.TotalPostScore DESC, ad.ReputationCategory;
