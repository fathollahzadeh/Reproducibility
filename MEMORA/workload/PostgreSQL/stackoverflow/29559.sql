
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COUNT(a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY COUNT(a.Id) DESC) AS RankByTags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostID,
        Title,
        Body,
        Tags,
        OwnerDisplayName,
        CreationDate,
        AnswerCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        RankByTags <= 5 
),
PostAnalysis AS (
    SELECT 
        fp.*,
        CHAR_LENGTH(fp.Body) AS BodyLength,
        CHAR_LENGTH(fp.Title) AS TitleLength,
        CASE 
            WHEN fp.AnswerCount > 0 THEN 'Answered' 
            ELSE 'Unanswered' 
        END AS PostStatus
    FROM 
        FilteredPosts fp
)
SELECT 
    PostID,
    Title,
    OwnerDisplayName,
    CreationDate,
    BodyLength,
    TitleLength,
    PostStatus,
    UpVotes,
    DownVotes
FROM 
    PostAnalysis
ORDER BY 
    UpVotes DESC, 
    CreationDate DESC
LIMIT 50;
