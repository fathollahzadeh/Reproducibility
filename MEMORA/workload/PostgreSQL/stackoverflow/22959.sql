
WITH UserReputation AS (
    SELECT 
        Id,
        Reputation,
        CreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(creator.DisplayName, 'Community User') AS OwnerDisplayName,
        COALESCE(pc.Count, 0) AS CommentCount,
        COALESCE(ba.BadgeCount, 0) AS BadgeCount,
        PHT.Name AS PostHistoryType,
        ph.CreationDate AS HistoryCreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Users creator ON p.OwnerUserId = creator.Id
    LEFT JOIN 
        (SELECT 
             PostId, 
             COUNT(*) AS Count 
         FROM 
             Comments 
         GROUP BY PostId) pc ON p.Id = pc.PostId
    LEFT JOIN 
        (SELECT 
             UserId, 
             COUNT(*) AS BadgeCount 
         FROM 
             Badges 
         GROUP BY UserId) ba ON creator.Id = ba.UserId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN 
        PostHistoryTypes PHT ON ph.PostHistoryTypeId = PHT.Id
),
PostEngagement AS (
    SELECT 
        pd.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        AVG(pd.ViewCount) AS AverageViews,
        COUNT(DISTINCT v.UserId) AS UniqueVoters
    FROM 
        PostDetails pd
    LEFT JOIN 
        Votes v ON pd.PostId = v.PostId
    GROUP BY 
        pd.PostId
),
PostAnalytics AS (
    SELECT 
        pd.*,
        pe.UpVotes,
        pe.DownVotes,
        pe.AverageViews,
        pe.UniqueVoters,
        CASE 
            WHEN pe.UpVotes - pe.DownVotes > 0 THEN 'Positive'
            WHEN pe.UpVotes - pe.DownVotes < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS PostSentiment
    FROM 
        PostDetails pd
    JOIN 
        PostEngagement pe ON pd.PostId = pe.PostId
)

SELECT 
    pa.PostId,
    pa.Title,
    pa.PostCreationDate,
    pa.OwnerDisplayName,
    pa.Score,
    pa.CommentCount,
    pa.BadgeCount,
    pa.AverageViews,
    pa.UniqueVoters,
    pa.PostSentiment,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Posts WHERE AcceptedAnswerId = pa.PostId) THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AcceptedAnswerStatus,
    STRING_AGG(DISTINCT pht.Name, ', ') AS PostHistoryTypes
FROM 
    PostAnalytics pa
LEFT JOIN 
    PostHistory ph ON pa.PostId = ph.PostId
LEFT JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
WHERE 
    pa.PostCreationDate > CAST('2024-10-01 12:34:56' AS TIMESTAMP) - INTERVAL '1 year'
GROUP BY 
    pa.PostId,
    pa.Title,
    pa.PostCreationDate,
    pa.OwnerDisplayName,
    pa.Score,
    pa.CommentCount,
    pa.BadgeCount,
    pa.AverageViews,
    pa.UniqueVoters,
    pa.PostSentiment
HAVING 
    COALESCE(pa.BadgeCount, 0) > 0 OR pa.UniqueVoters > 5
ORDER BY 
    pa.Score DESC, pa.AverageViews DESC
LIMIT 100;
