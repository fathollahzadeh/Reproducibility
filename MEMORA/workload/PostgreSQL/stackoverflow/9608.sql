WITH RankedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
),
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName 
    FROM 
        RankedUsers 
    WHERE 
        ReputationRank <= 10
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate AS PostCreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        u.DisplayName AS OwnerDisplayName
    FROM 
        Posts p 
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id 
    WHERE 
        p.CreationDate >= cast('2024-10-01' as date) - INTERVAL '30 days'
    GROUP BY 
        p.Id, u.DisplayName
),
CombinedResults AS (
    SELECT 
        t.UserId AS TopUserId,
        t.DisplayName AS TopUserName,
        pd.Title AS PostTitle,
        pd.PostCreationDate,
        pd.Score,
        pd.CommentCount,
        pd.UpVotes,
        pd.DownVotes
    FROM 
        TopUsers t
    LEFT JOIN 
        PostDetails pd ON pd.OwnerDisplayName = t.DisplayName
)

SELECT 
    TopUserName,
    COUNT(PostTitle) AS NumberOfPosts,
    SUM(Score) AS TotalScore,
    AVG(CommentCount) AS AverageComments,
    SUM(UpVotes) AS TotalUpVotes,
    SUM(DownVotes) AS TotalDownVotes
FROM 
    CombinedResults
GROUP BY 
    TopUserName
ORDER BY 
    TotalScore DESC;