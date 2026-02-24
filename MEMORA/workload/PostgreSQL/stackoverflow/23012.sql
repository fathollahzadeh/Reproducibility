WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        AVG(COALESCE(v.VoteTypeId, 0)) AS AverageVoteType,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        u.Id, u.Reputation
),
PostDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COALESCE(pc.CommentCount, 0) AS Comments,
        COALESCE(ph.RevisionCount, 0) AS RevisionCount,
        CASE 
            WHEN p.Score IS NULL THEN 'No Score'
            WHEN p.Score > 0 THEN 'Positive'
            WHEN p.Score < 0 THEN 'Negative'
            ELSE 'Unknown' 
        END AS ScoreDescription,
        p.Tags AS PostTags
    FROM
        Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) pc ON p.Id = pc.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS RevisionCount
        FROM PostHistory
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
),
RankedPosts AS (
    SELECT 
        pd.PostId, 
        pd.Title, 
        pd.Comments, 
        pd.RevisionCount,
        pd.ScoreDescription,
        pd.PostTags,
        DENSE_RANK() OVER (ORDER BY pd.Comments DESC) AS CommentRank
    FROM 
        PostDetails pd
    WHERE 
        pd.RevisionCount > 0
)
SELECT 
    ur.UserId,
    ur.Reputation,
    ur.PostCount,
    ur.PositivePosts,
    ur.AverageVoteType,
    rp.PostId,
    rp.Title,
    rp.Comments,
    rp.RevisionCount,
    rp.ScoreDescription,
    rp.PostTags
FROM 
    UserReputation ur
JOIN 
    RankedPosts rp ON ur.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)
WHERE 
    ur.Reputation IS NOT NULL
    AND rp.CommentRank <= 5
ORDER BY 
    ur.Reputation DESC, 
    rp.Comments DESC;