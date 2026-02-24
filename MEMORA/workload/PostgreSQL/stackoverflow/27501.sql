
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS RankByTag,
        p.OwnerUserId
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
),
TopRankedPosts AS (
    SELECT 
        rp.*
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByTag <= 5 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        COUNT(DISTINCT a.Id) AS AnswersProvided,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id AND p.PostTypeId = 1 
    LEFT JOIN 
        Posts a ON a.OwnerUserId = u.Id AND a.PostTypeId = 2 
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
CombinedData AS (
    SELECT 
        trp.Title,
        trp.Body,
        trp.CreationDate,
        trp.Score,
        ua.DisplayName AS UserDisplayName,
        ua.QuestionsAsked,
        ua.AnswersProvided,
        ua.UpVotesReceived
    FROM 
        TopRankedPosts trp
    JOIN 
        Users u ON trp.OwnerUserId = u.Id
    JOIN 
        UserActivity ua ON u.Id = ua.UserId
)
SELECT 
    Title,
    Body,
    CreationDate,
    Score,
    UserDisplayName,
    QuestionsAsked,
    AnswersProvided,
    UpVotesReceived
FROM 
    CombinedData
ORDER BY 
    Score DESC, CreationDate DESC
LIMIT 10;
