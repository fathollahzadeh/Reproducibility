
WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        ph.Title,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    WHERE 
        p.PostTypeId = 2  
),

UserScore AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(SUM(CASE WHEN v.CreationDate IS NOT NULL THEN 1 ELSE 0 END), 0) AS VoteCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
),

MostActiveUsers AS (
    SELECT 
        OwnerUserId AS UserId,
        COUNT(*) AS PostCount
    FROM 
        Posts
    GROUP BY 
        OwnerUserId
    HAVING 
        COUNT(*) > 10  
),

PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ph.Level,
        u.DisplayName AS OwnerDisplayName,
        UserScore.TotalBounties,
        UserScore.VoteCount,
        p.OwnerUserId  -- Added to GROUP BY
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN 
        UserScore ON u.Id = UserScore.UserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'  
    GROUP BY 
        p.Id, p.Title, ph.Level, u.DisplayName, UserScore.TotalBounties, UserScore.VoteCount, p.OwnerUserId
)

SELECT 
    pd.PostId,
    pd.Title,
    pd.UpVotes,
    pd.DownVotes,
    pd.Level,
    pd.OwnerDisplayName,
    pd.TotalBounties,
    pd.VoteCount,
    CASE 
        WHEN pd.UpVotes - pd.DownVotes > 0 THEN 'Positive'
        WHEN pd.UpVotes - pd.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS Sentiment
FROM 
    PostDetails pd
JOIN 
    MostActiveUsers mau ON pd.OwnerUserId = mau.UserId
ORDER BY 
    pd.UpVotes - pd.DownVotes DESC, 
    pd.PostId;
