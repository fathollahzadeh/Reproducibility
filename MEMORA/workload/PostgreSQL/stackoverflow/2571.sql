
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COALESCE(p.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.ViewCount, p.AcceptedAnswerId
),
FilteredPosts AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.CreationDate,
        pd.ViewCount,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes,
        ur.ReputationLevel
    FROM PostDetails pd
    JOIN UserReputation ur ON pd.AcceptedAnswerId = ur.UserId
    WHERE 
        pd.CommentCount > 0 
        AND pd.ViewCount > 100 
        AND ur.ReputationLevel = 'High'
),
FinalStats AS (
    SELECT 
        ReputationLevel,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        AVG(CAST(UpVotes AS FLOAT)) AS AvgUpVotes,
        AVG(CAST(DownVotes AS FLOAT)) AS AvgDownVotes
    FROM FilteredPosts
    GROUP BY ReputationLevel
)
SELECT 
    f.ReputationLevel,
    f.PostCount,
    f.TotalViews,
    f.AvgUpVotes,
    f.AvgDownVotes,
    CASE 
        WHEN f.PostCount > 0 THEN f.TotalViews / f.PostCount
        ELSE 0
    END AS AvgViewsPerPost
FROM FinalStats f
ORDER BY f.ReputationLevel;
