
WITH TagUsage AS (
    SELECT 
        unnest(string_to_array(Tags, '><')) AS TagName,
        p.Id AS PostId,
        p.OwnerUserId,
        p.CreationDate,
        p.Title,
        U.Reputation,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    LEFT JOIN 
        Users U ON U.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON b.UserId = U.Id
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        TagName, p.Id, U.Reputation, p.CreationDate, p.Title
),
TagStats AS (
    SELECT 
        TagName,
        COUNT(DISTINCT PostId) AS QuestionCount,
        SUM(UpVotes) AS TotalUpVotes,
        SUM(DownVotes) AS TotalDownVotes,
        SUM(CommentCount) AS TotalComments,
        SUM(BadgeCount) AS TotalBadges
    FROM 
        TagUsage
    GROUP BY 
        TagName
),
RankedTags AS (
    SELECT 
        TagName,
        QuestionCount,
        TotalUpVotes,
        TotalDownVotes,
        TotalComments,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY QuestionCount DESC, TotalUpVotes DESC) AS Rank
    FROM 
        TagStats
)

SELECT 
    TagName,
    QuestionCount,
    TotalUpVotes,
    TotalDownVotes,
    TotalComments,
    TotalBadges,
    Rank
FROM 
    RankedTags
WHERE 
    Rank <= 10 
ORDER BY 
    Rank;
