WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ARRAY_LENGTH(string_to_array(p.Tags, '><'), 1) AS TagCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS NegativeScoredQuestions
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
ActiveUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.QuestionCount,
        ur.PositiveScoredQuestions,
        ur.NegativeScoredQuestions,
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.TagCount,
        rp.CommentCount
    FROM 
        UserReputation ur
    JOIN 
        RankedPosts rp ON ur.UserId = rp.PostId
    WHERE 
        ur.QuestionCount > 10  
        AND ur.Reputation >= 100  
)
SELECT 
    au.DisplayName,
    au.Reputation,
    COUNT(DISTINCT au.PostId) AS NumberOfPosts,
    SUM(au.Score) AS TotalScore,
    AVG(au.ViewCount) AS AvgViewCount,
    AVG(au.CommentCount) AS AvgCommentCount,
    STRING_AGG(DISTINCT 'Title: ' || au.Title || ' (Score: ' || au.Score || ', Views: ' || au.ViewCount || ')', '; ') AS RecentPosts
FROM 
    ActiveUsers au
GROUP BY 
    au.DisplayName, au.Reputation
ORDER BY 
    au.Reputation DESC, NumberOfPosts DESC;