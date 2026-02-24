
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
        AND p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopContributors AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100  
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        tc.UserId,
        tc.DisplayName,
        COALESCE(NULLIF(EXTRACT(EPOCH FROM (TIMESTAMP '2024-10-01 12:34:56' - rp.CreationDate)) / 86400, 0), 0) AS DaysOld,
        CASE 
            WHEN rp.Score > 0 THEN 'Positive'
            WHEN rp.Score < 0 THEN 'Negative'
            ELSE 'Neutral'
        END AS Sentiment
    FROM 
        RankedPosts rp
    JOIN 
        TopContributors tc ON rp.PostId IN (
            SELECT p.Id 
            FROM Posts p 
            WHERE p.OwnerUserId = tc.UserId
        )
)
SELECT 
    pd.Title,
    pd.DaysOld,
    pd.Sentiment,
    COUNT(v.Id) AS VoteCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    PostDetails pd
LEFT JOIN 
    Votes v ON pd.PostId = v.PostId
GROUP BY 
    pd.Title, pd.DaysOld, pd.Sentiment
HAVING 
    COUNT(v.Id) > 5  
ORDER BY 
    pd.DaysOld, pd.Sentiment DESC;
