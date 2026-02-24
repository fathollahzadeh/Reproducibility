
WITH RecursivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.ViewCount,
        COALESCE(NULLIF(p.Body, ''), 'No content') AS Body,
        p.OwnerUserId,
        p.Score,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS OwnerPostRank
    FROM 
        Posts p
),
UserRankings AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
AboveAverageUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName
    FROM 
        UserRankings ur
    WHERE 
        ur.TotalScore > (SELECT AVG(TotalScore) FROM UserRankings)
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
FinalResults AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.ViewCount,
        au.DisplayName AS Author,
        COALESCE(pc.CommentCount, 0) AS Comments,
        ur.TotalScore,
        ur.QuestionCount,
        ur.PostCount
    FROM 
        RecursivePosts rp
    JOIN 
        AboveAverageUsers au ON rp.OwnerUserId = au.UserId
    LEFT JOIN 
        PostComments pc ON rp.PostId = pc.PostId
    JOIN 
        UserRankings ur ON ur.UserId = rp.OwnerUserId
)
SELECT 
    fr.PostId,
    fr.Title,
    fr.Body,
    fr.ViewCount,
    fr.Author,
    fr.Comments,
    fr.TotalScore,
    fr.QuestionCount,
    fr.PostCount,
    CASE 
        WHEN fr.Comments > 10 THEN 'Highly Discussed'
        WHEN fr.Comments BETWEEN 5 AND 10 THEN 'Moderately Discussed'
        ELSE 'Less Discussed' 
    END AS DiscussionLevel,
    CASE 
        WHEN fr.TotalScore >= 100 THEN 'High Reputation'
        WHEN fr.TotalScore >= 50 THEN 'Moderate Reputation'
        ELSE 'Low Reputation'
    END AS ReputationLevel
FROM 
    FinalResults fr
WHERE 
    fr.ViewCount > 50
ORDER BY 
    fr.ViewCount DESC, fr.TotalScore DESC
LIMIT 100 OFFSET 0;
