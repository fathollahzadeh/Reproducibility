WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.CreationDate, 
        p.OwnerUserId, 
        p.Score, 
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= cast('2024-10-01 12:34:56' as timestamp) - INTERVAL '1 year' AND 
        p.PostTypeId IN (1, 2)  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
), FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.CreationDate, 
        rp.OwnerUserId, 
        rp.Score, 
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank = 1
), UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.Views, 
        u.UpVotes, 
        u.DownVotes,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000
), CommentsStatistics AS (
    SELECT 
        p.Id AS PostId, 
        AVG(c.Score) AS AvgCommentScore, 
        COUNT(c.Id) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    ur.DisplayName AS OwnerDisplayName,
    COALESCE(ur.Reputation, 0) AS OwnerReputation,
    COALESCE(cs.AvgCommentScore, 0) AS AvgCommentScore,
    cs.TotalComments,
    CASE 
        WHEN ur.Reputation IS NULL THEN 'Unknown'
        ELSE CASE 
            WHEN ur.Reputation < 2000 THEN 'New Contributor'
            WHEN ur.Reputation < 5000 THEN 'Regular Contributor'
            ELSE 'Top Contributor'
        END
    END AS ContributorLevel
FROM 
    FilteredPosts fp
LEFT JOIN 
    UserReputation ur ON fp.OwnerUserId = ur.UserId
LEFT JOIN 
    CommentsStatistics cs ON fp.PostId = cs.PostId
WHERE 
    (fp.CommentCount > 0 OR ur.Reputation IS NOT NULL)
ORDER BY 
    fp.CreationDate DESC
LIMIT 100;