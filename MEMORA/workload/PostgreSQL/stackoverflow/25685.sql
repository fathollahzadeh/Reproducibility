WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, p.ViewCount, p.Score
),
TopRankedPosts AS (
    SELECT 
        PostID,
        Title,
        Body,
        Tags,
        CreationDate,
        OwnerDisplayName,
        ViewCount,
        Score
    FROM 
        RankedPosts
    WHERE 
        Rank = 1
),
UserEngagement AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesReceived,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesReceived
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    trp.Title,
    trp.Body,
    trp.Tags,
    trp.CreationDate,
    trp.OwnerDisplayName,
    trp.ViewCount,
    trp.Score,
    ue.DisplayName AS UserDisplayName,
    ue.QuestionsAsked,
    ue.UpVotesReceived,
    ue.DownVotesReceived
FROM 
    TopRankedPosts trp
JOIN 
    UserEngagement ue ON trp.OwnerDisplayName = ue.DisplayName
ORDER BY 
    trp.Score DESC, trp.CreationDate DESC;