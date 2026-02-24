WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation
    FROM 
        UserReputation
    WHERE 
        Rank <= 10
),
PostVotes AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
FilteredPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        pv.UpVotes,
        pv.DownVotes,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p
    JOIN 
        PostVotes pv ON p.Id = pv.PostId
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' 
        AND pv.TotalVotes > 0
),
PostDetails AS (
    SELECT 
        fp.Id,
        fp.Title,
        fp.CreationDate,
        fp.Score,
        fp.UpVotes,
        fp.DownVotes,
        fp.OwnerDisplayName,
        CASE 
            WHEN fp.UpVotes - fp.DownVotes < 0 THEN 'Negative'
            WHEN fp.UpVotes - fp.DownVotes = 0 THEN 'Neutral'
            ELSE 'Positive'
        END AS VoteSentiment
    FROM 
        FilteredPosts fp
)
SELECT 
    tu.DisplayName AS TopUser,
    pd.Title AS PostTitle,
    pd.Score,
    pd.UpVotes,
    pd.DownVotes,
    pd.VoteSentiment,
    CASE 
        WHEN pd.CreationDate < cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '30 days' THEN 'Archived'
        ELSE 'Active'
    END AS PostStatus
FROM 
    PostDetails pd
CROSS JOIN 
    TopUsers tu
WHERE 
    pd.Score > 10
ORDER BY 
    tu.Reputation DESC, 
    pd.Score DESC;