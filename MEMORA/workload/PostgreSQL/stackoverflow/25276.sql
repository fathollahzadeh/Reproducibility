
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Tags, p.CreationDate, p.Score
),
AggregateData AS (
    SELECT 
        Tags,
        COUNT(PostId) AS PostCount,
        SUM(CommentCount) AS TotalComments,
        SUM(AnswerCount) AS TotalAnswers,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes
    FROM 
        RankedPosts
    GROUP BY 
        Tags
),
FinalResults AS (
    SELECT 
        Tags,
        PostCount,
        TotalComments,
        TotalAnswers,
        TotalUpVotes,
        TotalDownVotes,
        (TotalUpVotes - TotalDownVotes) AS NetVotes,
        RANK() OVER (ORDER BY PostCount DESC) AS TagsRank
    FROM 
        AggregateData
)
SELECT 
    Tags,
    PostCount,
    TotalComments,
    TotalAnswers,
    TotalUpVotes,
    TotalDownVotes,
    NetVotes,
    TagsRank
FROM 
    FinalResults
WHERE 
    TagsRank <= 5
ORDER BY 
    TagsRank;
