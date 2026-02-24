
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (2, 3)  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags, u.DisplayName
),
TopQuestions AS (
    SELECT 
        Id,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        OwnerDisplayName,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank = 1
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10  
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        p.Title AS OldTitle,
        p.Body AS OldBody,
        STRING_AGG(cht.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    LEFT JOIN 
        Posts p ON ph.PostId = p.Id
    LEFT JOIN 
        CloseReasonTypes cht ON CAST(ph.Comment AS INT) = cht.Id  
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId, p.Title, p.Body
),
FinalOutput AS (
    SELECT 
        tq.Title AS QuestionTitle,
        tq.Body AS QuestionBody,
        tq.CreationDate AS QuestionDate,
        tq.Score AS QuestionScore,
        tq.ViewCount AS QuestionViewCount,
        tq.Tags AS QuestionTags,
        tq.OwnerDisplayName AS QuestionOwner,
        tq.CommentCount AS QuestionCommentCount,
        tq.VoteCount AS QuestionVoteCount,
        phd.OldTitle AS PostOldTitle,
        phd.OldBody AS PostOldBody,
        phd.CloseReasons AS PostCloseReasons
    FROM 
        TopQuestions tq
    LEFT JOIN 
        PostHistoryDetails phd ON tq.Id = phd.PostId
)
SELECT 
    *
FROM 
    FinalOutput
ORDER BY 
    QuestionScore DESC, QuestionViewCount DESC;
