
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.ViewCount,
        p.AcceptedAnswerId,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '1 year' 
        AND p.ViewCount >= 0
),
CommentCounts AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS TotalComments
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
VoteStatistics AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN v.VoteTypeId = 10 THEN 1 ELSE 0 END) AS Deletions
    FROM 
        Votes v
    GROUP BY 
        v.PostId
),
QuestionsWithAcceptedAnswers AS (
    SELECT 
        p.Id AS QuestionId,
        p.AcceptedAnswerId,
        COALESCE((SELECT COUNT(*) FROM Posts a WHERE a.Id = p.AcceptedAnswerId AND a.PostTypeId = 2), 0) AS IsAcceptedAnswer
    FROM 
        Posts p 
    WHERE 
        p.PostTypeId = 1
),
FinalPostData AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.ViewCount,
        rp.CreationDate,
        cc.TotalComments,
        vs.UpVotes,
        vs.DownVotes,
        qwa.IsAcceptedAnswer
    FROM 
        RankedPosts rp
    LEFT JOIN 
        CommentCounts cc ON rp.PostID = cc.PostId
    LEFT JOIN 
        VoteStatistics vs ON rp.PostID = vs.PostId
    LEFT JOIN 
        QuestionsWithAcceptedAnswers qwa ON rp.PostID = qwa.QuestionId
    WHERE 
        rp.RankByViews <= 10
)
SELECT 
    fpd.*,
    CASE 
        WHEN fpd.IsAcceptedAnswer = 1 THEN 'Accepted'
        ELSE 'Not Accepted' 
    END AS AnswerStatus,
    CASE
        WHEN fpd.TotalComments IS NULL THEN 'No Comments'
        ELSE CAST(fpd.TotalComments AS VARCHAR) || ' Comments'
    END AS CommentStatus,
    COALESCE(fpd.UpVotes, 0) - COALESCE(fpd.DownVotes, 0) AS NetVotes
FROM 
    FinalPostData fpd
WHERE 
    fpd.ViewCount IS NOT NULL
ORDER BY 
    fpd.ViewCount DESC,
    fpd.CreationDate ASC;
