
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        AVG(u.Reputation) AS AvgReputation,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COUNT(p.Id) DESC) AS RN
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        PostCount, 
        AnswerCount, 
        QuestionCount, 
        AvgReputation
    FROM 
        UserPostStats
    WHERE 
        RN <= 10
), 
PostVoteDetails AS (
    SELECT
        p.Id AS PostId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
), 
PostInfo AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        COALESCE(ph.Comment, 'No comments') AS LastEditComment,
        pvd.Upvotes,
        pvd.Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 4 
    LEFT JOIN
        PostVoteDetails pvd ON p.Id = pvd.PostId
), 
QualifiedPosts AS (
    SELECT 
        pi.PostId,
        pi.Title,
        pi.CreationDate,
        pi.ViewCount,
        pi.OwnerUserId,
        pi.LastEditComment,
        pi.Upvotes,
        pi.Downvotes,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        PostInfo pi
    LEFT JOIN 
        Comments c ON pi.PostId = c.PostId
    WHERE 
        pi.Upvotes - pi.Downvotes > 0 
    GROUP BY 
        pi.PostId, pi.Title, pi.CreationDate, pi.ViewCount, pi.OwnerUserId, pi.LastEditComment, pi.Upvotes, pi.Downvotes
), 
FinalResults AS (
    SELECT 
        pu.DisplayName,
        qp.Title,
        qp.CreationDate,
        qp.ViewCount,
        qp.LastEditComment,
        qp.CommentCount,
        qp.Upvotes,
        qp.Downvotes,
        DENSE_RANK() OVER (ORDER BY qp.Upvotes DESC) AS VoteRank
    FROM 
        QualifiedPosts qp
    INNER JOIN 
        TopUsers pu ON qp.OwnerUserId = pu.UserId
)

SELECT
    fr.*,
    CASE 
        WHEN fr.Upvotes = 0 AND fr.Downvotes = 0 THEN 'No Votes'
        WHEN fr.Upvotes - fr.Downvotes > 0 THEN 'Positive'
        WHEN fr.Upvotes - fr.Downvotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteStatus
FROM 
    FinalResults fr
WHERE 
    fr.VoteRank <= 5
ORDER BY 
    fr.VoteRank;
