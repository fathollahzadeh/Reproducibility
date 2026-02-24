WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        u.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
),
TopUsers AS (
    SELECT 
        OwnerDisplayName,
        SUM(Score) AS TotalScore,
        COUNT(*) AS TotalPosts
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
    GROUP BY 
        OwnerDisplayName
    ORDER BY 
        TotalScore DESC
    LIMIT 10
),
PostWithTopUsers AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        t.OwnerDisplayName,
        t.TotalScore,
        t.TotalPosts,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes
    FROM 
        Posts p
    JOIN 
        TopUsers t ON p.OwnerDisplayName = t.OwnerDisplayName
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT PostId, SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
                                    SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes 
         FROM Votes 
         GROUP BY PostId) v ON p.Id = v.PostId
)
SELECT 
    PostId,
    Title,
    CreationDate,
    OwnerDisplayName,
    TotalScore,
    TotalPosts,
    CommentCount,
    UpVotes,
    DownVotes
FROM 
    PostWithTopUsers
ORDER BY 
    TotalScore DESC, CreationDate DESC;
