
WITH UserReputationCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY CASE WHEN u.Reputation > 1000 THEN 'High' 
                                             WHEN u.Reputation > 500 THEN 'Medium' 
                                             ELSE 'Low' END 
                           ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
    WHERE 
        u.Reputation IS NOT NULL
),
PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(NULLIF(p.Score, 0), NULL) AS PostScore,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(ah.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Posts ah ON p.AcceptedAnswerId = ah.Id
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.Score, u.DisplayName, ah.AcceptedAnswerId
),
ReputationStatus AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        CASE 
            WHEN ur.Reputation > (SELECT AVG(Reputation) FROM Users) THEN 'Above Average'
            ELSE 'Below Average'
        END AS ReputationGroup
    FROM 
        UserReputationCTE ur
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.ViewCount,
    pd.PostScore,
    pd.OwnerDisplayName,
    rs.ReputationGroup,
    pd.CommentCount,
    pd.UpVotes,
    pd.DownVotes,
    COUNT(pl.RelatedPostId) AS RelatedPostsCount
FROM 
    PostDetails pd
LEFT JOIN 
    PostLinks pl ON pd.PostId = pl.PostId
JOIN 
    ReputationStatus rs ON pd.OwnerDisplayName = rs.DisplayName
WHERE 
    pd.ViewCount > 50 
    AND (pd.PostScore < 5 OR pd.PostScore IS NULL)
GROUP BY 
    pd.PostId, pd.Title, pd.ViewCount, pd.PostScore, pd.OwnerDisplayName, 
    rs.ReputationGroup, pd.CommentCount, pd.UpVotes, pd.DownVotes
HAVING 
    COUNT(pl.RelatedPostId) > 0
ORDER BY 
    pd.ViewCount DESC,
    pd.PostScore DESC  
OFFSET 10 ROWS FETCH NEXT 10 ROWS ONLY;
